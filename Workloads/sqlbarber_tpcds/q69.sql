SELECT d.d_year, COUNT(*) AS page_count FROM web_page wp INNER JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk WHERE d.d_year = 1905 GROUP BY d.d_year
