-- Stored Procedure: Auto-close expired surveys
CREATE OR REPLACE PROCEDURE pr_close_expired_surveys()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE survey
    SET status = 'CLOSED'
    WHERE status = 'PUBLISHED' 
      AND endDate IS NOT NULL 
      AND endDate < CURRENT_TIMESTAMP;
    COMMIT;
END;
$$;

-- Stored Function: Calculate completion rate for a survey
CREATE OR REPLACE FUNCTION fn_get_completion_rate(p_survey_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_questions INT;
    v_total_responses INT;
BEGIN
    SELECT COUNT(*) INTO v_total_questions FROM question WHERE surveyId = p_survey_id;
    SELECT COUNT(*) INTO v_total_responses FROM survey_response WHERE surveyId = p_survey_id;
    IF v_total_responses = 0 THEN RETURN 0; END IF;
    RETURN (SELECT COUNT(*) FROM response_answer ra 
            JOIN survey_response sr ON ra.responseId = sr.id 
            WHERE sr.surveyId = p_survey_id)::NUMERIC / (v_total_questions * v_total_responses);
END;
$$;

-- Stored Procedure: Validate and Publish Survey
CREATE OR REPLACE PROCEDURE pr_validate_and_publish_survey(p_survey_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_question_count INT;
    v_current_status TEXT;
BEGIN
    -- Check if survey exists
    SELECT status INTO v_current_status 
    FROM survey 
    WHERE id = p_survey_id;
    
    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Survey with ID % not found', p_survey_id;
    END IF;
    
    -- Check if survey has at least one question
    SELECT COUNT(*) INTO v_question_count 
    FROM question 
    WHERE surveyId = p_survey_id;
    
    IF v_question_count = 0 THEN
        RAISE EXCEPTION 'Cannot publish survey without questions';
    END IF;
    
    -- Update survey status to PUBLISHED
    UPDATE survey
    SET status = 'PUBLISHED', updatedAt = CURRENT_TIMESTAMP
    WHERE id = p_survey_id;
    
    COMMIT;
    
    RAISE NOTICE 'Survey % published successfully with % questions', p_survey_id, v_question_count;
END;
$$;

