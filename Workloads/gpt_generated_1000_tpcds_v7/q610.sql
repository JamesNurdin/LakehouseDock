WITH returns_high_qty AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        'high_qty' AS segment
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_units = 'Each'
      AND sr.sr_return_quantity > 20
      AND s.s_city = 'Lee'
    GROUP BY s.s_store_id, s.s_store_name
),
returns_low_qty AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        'low_qty' AS segment
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 10
      AND sr.sr_return_quantity <= 20
      AND s.s_hours = '8AM-12AM'
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT s_store_id,
       s_store_name,
       total_return_inc_tax,
       segment
FROM returns_high_qty
UNION ALL
SELECT s_store_id,
       s_store_name,
       total_return_inc_tax,
       segment
FROM returns_low_qty
ORDER BY total_return_inc_tax DESC
