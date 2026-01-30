package repository

import (
	"github.com/bugdrill/backend/internal/database"
	"github.com/bugdrill/backend/internal/model"
)

type PatternRepository struct {
	db *database.DB
}

func NewPatternRepository(db *database.DB) *PatternRepository {
	return &PatternRepository{db: db}
}

func (r *PatternRepository) GetAll() ([]model.PatternCategory, error) {
	query := `
		SELECT id, name, slug, description, icon_url, order_index
		FROM pattern_categories
		ORDER BY order_index
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var patterns []model.PatternCategory
	for rows.Next() {
		var p model.PatternCategory
		if err := rows.Scan(&p.ID, &p.Name, &p.Slug, &p.Description, &p.IconURL, &p.OrderIndex); err != nil {
			return nil, err
		}
		patterns = append(patterns, p)
	}
	return patterns, rows.Err()
}

func (r *PatternRepository) GetByID(id int) (*model.PatternCategory, error) {
	query := `
		SELECT id, name, slug, description, icon_url, order_index
		FROM pattern_categories
		WHERE id = $1
	`
	var p model.PatternCategory
	err := r.db.QueryRow(query, id).Scan(&p.ID, &p.Name, &p.Slug, &p.Description, &p.IconURL, &p.OrderIndex)
	if err != nil {
		return nil, err
	}
	return &p, nil
}
