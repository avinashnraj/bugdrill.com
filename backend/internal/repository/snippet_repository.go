package repository

import (
	"github.com/bugdrill/backend/internal/database"
	"github.com/bugdrill/backend/internal/model"
)

type SnippetRepository struct {
	db *database.DB
}

func NewSnippetRepository(db *database.DB) *SnippetRepository {
	return &SnippetRepository{db: db}
}

func (r *SnippetRepository) GetByID(id string) (*model.Snippet, error) {
	query := `
		SELECT id, pattern_id, title, description, difficulty, language,
		       correct_code, buggy_code, bug_type, bug_explanation,
		       test_cases, hint_1, hint_2, hint_3,
		       created_by, status, created_at, updated_at
		FROM snippets
		WHERE id = $1 AND status = 'active'
	`
	var s model.Snippet
	err := r.db.QueryRow(query, id).Scan(
		&s.ID, &s.PatternID, &s.Title, &s.Description, &s.Difficulty, &s.Language,
		&s.CorrectCode, &s.BuggyCode, &s.BugType, &s.BugExplanation,
		&s.TestCases, &s.Hint1, &s.Hint2, &s.Hint3,
		&s.CreatedBy, &s.Status, &s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *SnippetRepository) GetByPatternID(patternID int, difficulty string) ([]model.Snippet, error) {
	query := `
		SELECT id, pattern_id, title, description, difficulty, language,
		       bug_type, created_at
		FROM snippets
		WHERE pattern_id = $1 AND status = 'active'
	`
	args := []interface{}{patternID}

	if difficulty != "" {
		query += ` AND difficulty = $2`
		args = append(args, difficulty)
	}

	query += ` ORDER BY difficulty, title`

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var snippets []model.Snippet
	for rows.Next() {
		var s model.Snippet
		if err := rows.Scan(&s.ID, &s.PatternID, &s.Title, &s.Description, &s.Difficulty, &s.Language, &s.BugType, &s.CreatedAt); err != nil {
			return nil, err
		}
		snippets = append(snippets, s)
	}
	return snippets, rows.Err()
}

func (r *SnippetRepository) Create(snippet *model.Snippet) error {
	query := `
		INSERT INTO snippets (
			id, pattern_id, title, description, difficulty, language,
			correct_code, buggy_code, bug_type, bug_explanation,
			test_cases, hint_1, hint_2, hint_3, created_by, status
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
		RETURNING created_at, updated_at
	`
	return r.db.QueryRow(
		query,
		snippet.ID, snippet.PatternID, snippet.Title, snippet.Description,
		snippet.Difficulty, snippet.Language, snippet.CorrectCode, snippet.BuggyCode,
		snippet.BugType, snippet.BugExplanation, snippet.TestCases,
		snippet.Hint1, snippet.Hint2, snippet.Hint3, snippet.CreatedBy, snippet.Status,
	).Scan(&snippet.CreatedAt, &snippet.UpdatedAt)
}
