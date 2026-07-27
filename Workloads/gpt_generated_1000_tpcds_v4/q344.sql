WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i.i_manufact,
        td.t_meal_time,
        ca_ref.ca_state,
        ca_ref.ca_zip,
        ca_ref.ca_street_number
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE td.t_meal_time = 'lunch'
      AND td.t_minute BETWEEN 10 AND 20
      AND ca_ref.ca_zip IN ('68252', '39431')
      AND i.i_manufact = 'ationcallyought'
      AND i.i_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND ca_ref.ca_street_number = '585'
)
SELECT
    i_manufact,
    t_meal_time,
    ca_state,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM filtered
GROUP BY i_manufact, t_meal_time, ca_state
HAVING SUM(cr_return_amount) > 1000
   AND COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
