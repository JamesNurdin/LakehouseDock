WITH
first_part AS (
    SELECT
        cs.cs_order_number AS order_number,
        d_sold.d_year AS year,
        s.s_store_name AS store_name,
        r.r_reason_desc AS reason_desc,
        cs.cs_net_profit AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        (
            SELECT SUM(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d_sold.d_date_sk
        ) AS total_day_sales,
        lc.store_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk                                 --1
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk                                 --2
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk                                 --3
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d_sold.d_date_sk                             --4
    JOIN time_dim t_ret
      ON sr.sr_return_time_sk = t_ret.t_time_sk                                 --5
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk                                          --6
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk                                        --7
    FULL OUTER JOIN store s_closed
      ON s_closed.s_closed_date_sk = d_ship.d_date_sk                            --8
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS store_cnt
        FROM store s2
        WHERE s2.s_market_id = s.s_market_id
    ) lc ON TRUE                                                             --9
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = r.r_reason_sk
          AND sr2.sr_returned_date_sk = d_sold.d_date_sk
          AND sr2.sr_return_quantity > 10
    )
      AND cs.cs_net_profit > 0
      AND d_sold.d_holiday = 'N'
),
second_part AS (
    SELECT
        cs.cs_order_number AS order_number,
        d_sold.d_year AS year,
        s.s_store_name AS store_name,
        r.r_reason_desc AS reason_desc,
        cs.cs_net_profit AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        (
            SELECT SUM(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d_sold.d_date_sk
        ) AS total_day_sales,
        lc.store_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk                                 --1
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk                                 --2
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk                                 --3
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d_ship.d_date_sk                             --4 (different path)
    JOIN time_dim t_ret
      ON sr.sr_return_time_sk = t_ret.t_time_sk                                 --5
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk                                          --6
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk                                        --7
    FULL OUTER JOIN store s_closed
      ON s_closed.s_closed_date_sk = d_ship.d_date_sk                            --8
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS store_cnt
        FROM store s2
        WHERE s2.s_market_id = s.s_market_id
    ) lc ON TRUE                                                             --9
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = r.r_reason_sk
          AND sr2.sr_returned_date_sk = d_ship.d_date_sk
          AND sr2.sr_return_quantity > 10
    )
      AND cs.cs_net_profit > 0
      AND d_sold.d_holiday = 'Y'
)
SELECT
    u.order_number,
    u.year,
    u.store_name,
    u.reason_desc,
    u.net_profit,
    u.profit_rank,
    u.total_day_sales,
    u.store_cnt
FROM (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
) u
ORDER BY u.net_profit DESC
LIMIT 100
