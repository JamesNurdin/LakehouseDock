WITH cte_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        i.i_item_sk,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t1
        ON ss.ss_sold_time_sk = t1.t_time_sk
    WHERE s.s_state = 'CA'
      AND t1.t_hour BETWEEN 8 AND 12
      AND i.i_brand = 'Brand#12'
    GROUP BY ss.ss_store_sk, i.i_item_sk
)
SELECT DISTINCT
    s.s_store_name,
    i.i_product_name,
    cte.store_profit,
    cr.cr_return_amount,
    wr_tot.wr_return_total,
    (cte.store_profit - cr.cr_return_amount - wr_tot.wr_return_total) AS net_contribution
FROM cte_sales_agg cte
JOIN store s
    ON cte.ss_store_sk = s.s_store_sk
JOIN item i
    ON cte.i_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim t2
    ON cr.cr_returned_time_sk = t2.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
CROSS JOIN LATERAL (
    SELECT COALESCE(SUM(wr.wr_return_amt), 0) AS wr_return_total
    FROM web_returns wr
    JOIN time_dim t3
        ON wr.wr_returned_time_sk = t3.t_time_sk
    WHERE wr.wr_item_sk = i.i_item_sk
      AND t3.t_hour BETWEEN 9 AND 11
      AND wr.wr_return_amt > 10
) wr_tot
WHERE cc.cc_market_manager = 'Megan'
  AND cr.cr_fee > 20
  AND cr.cr_store_credit > 50
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN time_dim t3
            ON wr.wr_returned_time_sk = t3.t_time_sk
        WHERE wr.wr_item_sk = i.i_item_sk
          AND t3.t_hour BETWEEN 9 AND 11
          AND wr.wr_return_amt > 10
    )
GROUP BY s.s_store_name, i.i_product_name, cte.store_profit, cr.cr_return_amount, wr_tot.wr_return_total
HAVING cte.store_profit > 1000
ORDER BY net_contribution DESC
LIMIT 100
