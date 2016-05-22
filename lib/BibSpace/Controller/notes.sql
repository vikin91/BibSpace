

-- Delete authors that have no papers in the system - not harmful
DELETE FROM Author WHERE id NOT IN (SELECT DISTINCT author_id FROM Entry_to_Author);