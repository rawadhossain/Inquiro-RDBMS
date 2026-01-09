-- View 1: Survey Aggregate Performance
CREATE OR REPLACE VIEW vw_survey_performance AS
SELECT 
    s.id AS survey_id,
    s.title,
    u.name AS creator_name,
    COUNT(sr.id) AS total_responses,
    MAX(sr.createdAt) AS last_response_at
FROM survey s
JOIN "user" u ON s.creatorId = u.id
LEFT JOIN survey_response sr ON s.id = sr.surveyId
GROUP BY s.id, s.title, u.name;

-- View 2: Detailed Question Analytics
CREATE OR REPLACE VIEW vw_question_analytics AS
SELECT 
    q.id AS question_id,
    q.text AS question_text,
    q.type,
    s.title AS survey_title,
    COUNT(ra.id) AS answer_count
FROM question q
JOIN survey s ON q.surveyId = s.id
LEFT JOIN response_answer ra ON q.id = ra.questionId
GROUP BY q.id, q.text, q.type, s.title;