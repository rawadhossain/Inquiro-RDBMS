CREATE OR REPLACE FUNCTION tr_fn_audit_survey_status()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO system_audit_log (table_name, record_id, old_value, new_value)
        VALUES ('survey', NEW.id::TEXT, OLD.status::TEXT, NEW.status::TEXT);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_audit_survey_status
AFTER UPDATE ON survey
FOR EACH ROW
EXECUTE FUNCTION tr_fn_audit_survey_status();