-- Index 1: Optimize survey lookups by status and date
CREATE INDEX idx_survey_status_dates ON survey (status, startDate, endDate);

-- Index 2: Full-text search index for survey titles
CREATE INDEX idx_survey_title_search ON survey USING gin(to_tsvector('english', title));

-- Index 3: Performance for response queries
CREATE INDEX idx_responses_composite ON survey_response (surveyId, createdAt DESC);