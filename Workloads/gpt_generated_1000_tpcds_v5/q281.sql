WITH returns_by_category AS (
    SELECT
        i.i_category AS category,
        'return' AS metric,
        SUM(sr.sr_return_amt_inc_tax) AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND ca.ca_state = 'CA'
      AND i.i_current_price > 5
    GROUP BY i.i_category
), promotions_by_category AS (
    SELECT
        i.i_category AS category,
        'promotion' AS metric,
        SUM(p.p_cost) AS amount
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d_start.d_year = 2020 OR d_end.d_year = 2020
    GROUP BY i.i_category
)
SELECT category, metric, amount
FROM returns_by_category
UNION ALL
SELECT category, metric, amount
FROM promotions_by_category
ORDER BY category, metric, amount DESC
LIMIT 100
