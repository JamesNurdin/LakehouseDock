WITH store_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(sr.sr_net_loss) DESC) AS state_rank,
        CONCAT(ca.ca_city, '-', SUBSTR(ca.ca_address_id, 1, 5)) AS city_address_key,
        REGEXP_EXTRACT(ca.ca_street_name, '([0-9]+)') AS street_number_extracted,
        (
            SELECT AVG(p.p_cost)
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND EXISTS (
                  SELECT 1 FROM date_dim d_start
                  WHERE p.p_start_date_sk = d_start.d_date_sk
                    AND d_start.d_year = 2020
              )
        ) AS avg_promo_cost
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(ca.ca_street_name, '.*(Center|Street).*')
      AND ca.ca_country = 'United States'
      AND ca.ca_city LIKE 'A%'
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq, ca.ca_city, ca.ca_address_id, ca.ca_street_name, i.i_item_sk
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 8000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(wr.wr_net_loss) DESC) AS state_rank,
        CONCAT(ca.ca_city, '-', SUBSTR(ca.ca_address_id, 1, 5)) AS city_address_key,
        REGEXP_EXTRACT(ca.ca_street_name, '([0-9]+)') AS street_number_extracted,
        (
            SELECT AVG(p.p_cost)
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND EXISTS (
                  SELECT 1 FROM date_dim d_start
                  WHERE p.p_start_date_sk = d_start.d_date_sk
                    AND d_start.d_year = 2020
              )
        ) AS avg_promo_cost
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(ca.ca_street_name, '.*(Center|Street).*')
      AND ca.ca_country = 'United States'
      AND ca.ca_city LIKE 'A%'
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq, ca.ca_city, ca.ca_address_id, ca.ca_street_name, i.i_item_sk
)
SELECT
    state,
    year,
    month_seq,
    total_net_loss,
    return_cnt,
    loss_category,
    state_rank,
    city_address_key,
    street_number_extracted,
    avg_promo_cost,
    return_channel
FROM (
    SELECT *, 'store' AS return_channel FROM store_agg
    UNION ALL
    SELECT *, 'web'   AS return_channel FROM web_agg
) combined
ORDER BY total_net_loss DESC, state
LIMIT 100
