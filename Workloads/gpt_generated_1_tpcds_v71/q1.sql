WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_warehouse_sk,
        cs_call_center_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451120
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_call_center_sk
),
agg_data AS (
    SELECT
        s.s_state,
        w.w_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        SUM(cs_agg.total_sales) AS agg_sales,
        AVG(cs_agg.total_profit) AS avg_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(CASE WHEN cs_agg.total_profit > 0 THEN cs_agg.total_profit ELSE 0 END) AS pos_profit
    FROM cs_agg
    JOIN catalog_returns cr ON cr.cr_item_sk = cs_agg.cs_item_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN warehouse w ON w.w_warehouse_sk = cs_agg.cs_warehouse_sk
    JOIN customer c ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        s.s_state = 'PA'
        AND w.w_state = 'TX'
        AND ib.ib_lower_bound >= 60000
        AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
        AND cc.cc_market_manager = 'John Doe'
        AND we.web_company_name = 'Acme Corp'
        AND cs_agg.total_sales > 5000
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND EXISTS (
            SELECT 1 FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 5000
        )
    GROUP BY
        s.s_state,
        w.w_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
)
SELECT
    a.s_state,
    a.w_state,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.r_reason_desc,
    a.agg_sales,
    a.avg_profit,
    a.unique_customers,
    a.pos_profit,
    CASE WHEN a.agg_sales > 20000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.agg_sales DESC) AS sales_rank_state
FROM agg_data a
ORDER BY a.agg_sales DESC
LIMIT 100
