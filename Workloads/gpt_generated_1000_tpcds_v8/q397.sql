WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        td.t_hour,
        s.s_state,
        i.i_category,
        i.i_item_id,
        r.r_reason_desc,
        ib.ib_lower_bound,
        c.c_birth_year
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_order_number = cs.cs_order_number
       AND ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_hour = 14
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1970 AND 1980
      AND r.r_reason_desc LIKE '%size%'
      AND ib.ib_lower_bound >= 50000
      AND EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
              AND ss2.ss_sold_date_sk = cs.cs_sold_date_sk
          )
)
SELECT
    profit_status,
    t_hour,
    s_state,
    i_category,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit
FROM base_sales
GROUP BY profit_status, t_hour, s_state, i_category
UNION
SELECT
    profit_status,
    t_hour,
    s_state,
    i_category,
    SUM(cs_net_paid) * 0.9 AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit
FROM base_sales
WHERE cs_net_profit <= 0
GROUP BY profit_status, t_hour, s_state, i_category
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
