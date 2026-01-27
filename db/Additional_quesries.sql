SELECT 
    s.id,
    s.title,
    s.description,
    s.status,
    s.isPublic,
    s.allowAnonymous,
    s.startDate,
    s.endDate,
    s.createdAt,
    u.id as creator_id,
    u.name as creator_name,
    u.email as creator_email,
    COUNT(DISTINCT q.id) as question_count,
    COUNT(DISTINCT sr.id) as response_count
FROM survey s
JOIN "user" u ON s.creatorId = u.id
LEFT JOIN question q ON s.id = q.surveyId
LEFT JOIN survey_response sr ON s.id = sr.surveyId
WHERE s.status = 'PUBLISHED'
  AND s.isPublic = true
  AND (s.startDate IS NULL OR s.startDate <= CURRENT_TIMESTAMP)
  AND (s.endDate IS NULL OR s.endDate >= CURRENT_TIMESTAMP)
GROUP BY s.id, s.title, s.description, s.status, s.isPublic, 
         s.allowAnonymous, s.startDate, s.endDate, s.createdAt,
         u.id, u.name, u.email
ORDER BY s.createdAt DESC;


-- Q2: Get Survey with Questions and Options
-- Used in: surveyDAL.getSurveyById()
SELECT 
    s.*,
    u.id as creator_id,
    u.name as creator_name,
    u.email as creator_email,
    COUNT(DISTINCT sr.id) as response_count
FROM survey s
JOIN "user" u ON s.creatorId = u.id
LEFT JOIN survey_response sr ON s.id = sr.surveyId
WHERE s.id = $1
GROUP BY s.id, u.id, u.name, u.email;

-- Get questions for the survey
SELECT 
    q.*,
    json_agg(
        json_build_object(
            'id', qo.id,
            'text', qo.text,
            'value', qo.value,
            'order', qo."order"
        ) ORDER BY qo."order"
    ) FILTER (WHERE qo.id IS NOT NULL) as options
FROM question q
LEFT JOIN question_option qo ON q.id = qo.questionId
WHERE q.surveyId = $1
GROUP BY q.id
ORDER BY q."order";


-- Q3: Get Survey Responses with Answers
-- Used in: responseDAL.getResponsesBySurvey()
SELECT 
    sr.id,
    sr.isAnonymous,
    sr.ipAddress,
    sr.userAgent,
    sr.completedAt,
    sr.createdAt,
    sr.surveyId,
    u.id as respondent_id,
    u.name as respondent_name,
    u.email as respondent_email
FROM survey_response sr
LEFT JOIN "user" u ON sr.respondentId = u.id
WHERE sr.surveyId = $1
ORDER BY sr.createdAt DESC;

-- Get answers for each response
SELECT 
    ra.id,
    ra.textValue,
    ra.numberValue,
    ra.dateValue,
    ra.booleanValue,
    ra.responseId,
    ra.questionId,
    ra.selectedOptionId,
    q.text as question_text,
    q.type as question_type,
    qo.text as selected_option_text
FROM response_answer ra
JOIN question q ON ra.questionId = q.id
LEFT JOIN question_option qo ON ra.selectedOptionId = qo.id
WHERE ra.responseId = $1;


-- Q4: Validate Survey Token
-- Used in: tokenDAL.getSurveyByToken()
SELECT 
    st.id,
    st.token,
    st.isActive,
    st.expiresAt,
    st.maxUses,
    st.currentUses,
    st.surveyId
FROM survey_token st
WHERE st.token = $1
  AND st.isActive = true
  AND (st.expiresAt IS NULL OR st.expiresAt > CURRENT_TIMESTAMP)
  AND (st.maxUses IS NULL OR st.currentUses < st.maxUses);


-- Q5: Count Responses for Survey
-- Used in: responseDAL.getResponseCount()
SELECT COUNT(*) as response_count
FROM survey_response
WHERE surveyId = $1;


-- Q6: Check if User Has Responded
-- Used in: responseDAL.hasUserResponded()
SELECT EXISTS(
    SELECT 1 
    FROM survey_response 
    WHERE surveyId = $1 AND respondentId = $2
) as has_responded;


-- Q7: Get User's Surveys with Stats
-- Used in: surveyDAL.getSurveysByUser()
SELECT 
    s.id,
    s.title,
    s.description,
    s.status,
    s.isPublic,
    s.createdAt,
    s.updatedAt,
    COUNT(DISTINCT q.id) as question_count,
    COUNT(DISTINCT sr.id) as response_count
FROM survey s
LEFT JOIN question q ON s.id = q.surveyId
LEFT JOIN survey_response sr ON s.id = sr.surveyId
WHERE s.creatorId = $1
GROUP BY s.id
ORDER BY s.createdAt DESC;


-- Q8: Get Answers by Question
-- Used in: responseDAL.getAnswersByQuestion()
SELECT 
    ra.id,
    ra.textValue,
    ra.numberValue,
    ra.dateValue,
    ra.booleanValue,
    ra.selectedOptionId,
    qo.text as selected_option_text,
    sr.id as response_id,
    sr.createdAt as response_created_at,
    sr.isAnonymous
FROM response_answer ra
JOIN survey_response sr ON ra.responseId = sr.id
LEFT JOIN question_option qo ON ra.selectedOptionId = qo.id
WHERE ra.questionId = $1
ORDER BY sr.createdAt DESC;


-- Q9: Get Survey Tokens
-- Used in: tokenDAL.getTokensBySurvey()
SELECT 
    st.id,
    st.token,
    st.isActive,
    st.expiresAt,
    st.maxUses,
    st.currentUses,
    st.createdAt,
    st.updatedAt,
    COUNT(sr.id) as usage_count
FROM survey_token st
LEFT JOIN survey_response sr ON st.id = sr.tokenId
WHERE st.surveyId = $1
GROUP BY st.id
ORDER BY st.createdAt DESC;


-- Q10: Survey Performance Overview
-- Multi-table join with aggregations
SELECT 
    s.id,
    s.title,
    s.status,
    u.name as creator_name,
    COUNT(DISTINCT sr.id) as total_responses,
    COUNT(DISTINCT sr.respondentId) as unique_respondents,
    COUNT(DISTINCT q.id) as question_count,
    MAX(sr.createdAt) as last_response_at,
    MIN(sr.createdAt) as first_response_at
FROM survey s
JOIN "user" u ON s.creatorId = u.id
LEFT JOIN survey_response sr ON s.id = sr.surveyId
LEFT JOIN question q ON s.id = q.surveyId
GROUP BY s.id, s.title, s.status, u.name
ORDER BY total_responses DESC;


-- Q11: Response Time Analysis
-- Analytical query with time calculations
SELECT 
    s.id,
    s.title,
    COUNT(sr.id) as response_count,
    AVG(EXTRACT(EPOCH FROM (sr.completedAt - sr.createdAt))) as avg_duration_seconds,
    MIN(EXTRACT(EPOCH FROM (sr.completedAt - sr.createdAt))) as min_duration_seconds,
    MAX(EXTRACT(EPOCH FROM (sr.completedAt - sr.createdAt))) as max_duration_seconds
FROM survey s
JOIN survey_response sr ON s.id = sr.surveyId
WHERE sr.completedAt IS NOT NULL
GROUP BY s.id, s.title
HAVING COUNT(sr.id) > 0;


-- Q12: Question Response Distribution
-- For multiple choice questions
SELECT 
    q.id as question_id,
    q.text as question_text,
    qo.id as option_id,
    qo.text as option_text,
    COUNT(ra.id) as selection_count,
    ROUND(
        COUNT(ra.id) * 100.0 / 
        NULLIF(SUM(COUNT(ra.id)) OVER (PARTITION BY q.id), 0), 
        2
    ) as percentage
FROM question q
JOIN question_option qo ON q.id = qo.questionId
LEFT JOIN response_answer ra ON qo.id = ra.selectedOptionId
WHERE q.surveyId = $1
GROUP BY q.id, q.text, qo.id, qo.text
ORDER BY q.id, selection_count DESC;


-- Q13: User Activity Summary
-- Nested subqueries
SELECT 
    u.id,
    u.name,
    u.email,
    u.role,
    (SELECT COUNT(*) FROM survey WHERE creatorId = u.id) as surveys_created,
    (SELECT COUNT(*) FROM survey_response WHERE respondentId = u.id) as surveys_responded
FROM "user" u
WHERE u.role = 'CREATOR'
ORDER BY surveys_created DESC;


-- Q14: Anonymous vs Identified Responses
-- Conditional aggregation
SELECT 
    s.id,
    s.title,
    COUNT(CASE WHEN sr.isAnonymous = true THEN 1 END) as anonymous_count,
    COUNT(CASE WHEN sr.isAnonymous = false THEN 1 END) as identified_count,
    COUNT(sr.id) as total_responses,
    ROUND(
        COUNT(CASE WHEN sr.isAnonymous = true THEN 1 END) * 100.0 / 
        NULLIF(COUNT(sr.id), 0), 
        2
    ) as anonymous_percentage
FROM survey s
LEFT JOIN survey_response sr ON s.id = sr.surveyId
WHERE s.status = 'PUBLISHED'
GROUP BY s.id, s.title
HAVING COUNT(sr.id) > 0;