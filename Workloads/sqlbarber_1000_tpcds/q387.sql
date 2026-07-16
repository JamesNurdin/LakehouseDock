SELECT d.d_year, SUM(i.inv_quantity_on_hand) AS total_quantity FROM inventory i JOIN date_dim d ON i.inv_date_sk = d.d_date_sk WHERE d.d_year = 1903 GROUP BY d.d_year
