SELECT d.d_year, COUNT(s.s_store_sk) AS store_count FROM store s JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk WHERE d.d_year = 1926 GROUP BY d.d_year
