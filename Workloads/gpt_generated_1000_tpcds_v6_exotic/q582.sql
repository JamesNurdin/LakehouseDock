WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        td_cs.t_meal_time,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_return_amt,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        c_sr.c_customer_sk,
        cs.cs_list_price,
        cd_cs.cd_marital_status,
        w_cs.w_warehouse_sq_ft,
        r.r_reason_desc
    FROM
        store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
        JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c_sr.c_customer_sk
        JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
        JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c_sr.c_customer_sk
        JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE
        cs.cs_list_price > 100
        AND cd_cs.cd_marital_status = 'M'
        AND td_cs.t_meal_time = 'dinner'
        AND s.s_state = 'CA'
        AND w_cs.w_warehouse_sq_ft > 50000
        AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND r2.r_reason_desc = 'Damaged'
        )
),
agg AS (
    SELECT
        s_store_id,
        s_state,
        t_meal_time,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(cs_net_profit) AS total_cs_profit,
        SUM(ws_net_profit) AS total_ws_profit,
        SUM(sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers
    FROM base
    GROUP BY s_store_id, s_state, t_meal_time
)
SELECT
    s_store_id,
    s_state,
    t_meal_time,
    total_catalog_sales,
    total_web_sales,
    total_return_amount,
    (total_cs_profit + total_ws_profit - total_return_loss) AS net_profit,
    CASE WHEN (total_cs_profit + total_ws_profit - total_return_loss) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY (total_catalog_sales + total_web_sales) DESC) AS sales_rank
FROM agg
ORDER BY net_profit DESC
LIMIT 100
