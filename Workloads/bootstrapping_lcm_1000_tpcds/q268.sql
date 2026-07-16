SELECT
    d.d_year,
    d.d_moy AS month_of_year,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    wp.wp_type,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_return_amount,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND wp.wp_type IS NOT NULL
GROUP BY
    d.d_year,
    d.d_moy,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    wp.wp_type
HAVING COUNT(*) > 20
ORDER BY total_net_loss DESC
LIMIT 200
