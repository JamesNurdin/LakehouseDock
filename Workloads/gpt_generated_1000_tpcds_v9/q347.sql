WITH sampled_cs AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (5)
),
agg_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        c.cc_name,
        w.w_warehouse_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM sampled_cs cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center c
        ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd_cs
        ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    JOIN tpcds.household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    -- web sales and its dimensions
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.customer_demographics cd_ws
        ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN tpcds.household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    -- store returns and its dimensions
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN tpcds.household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_net_profit > 0
      AND ws.ws_quantity > 1
      AND ws.ws_net_paid > 0
      AND sr.sr_return_amt > 0
      AND i.i_current_price BETWEEN 20 AND 200
      AND c.cc_state = 'CA'
      AND hd_cs.hd_vehicle_count >= 1
      AND ib.ib_upper_bound > 50000
      AND ws_site.web_company_id IN (1, 2)
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        c.cc_name,
        w.w_warehouse_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_return_amt) > 1000
       AND COUNT(DISTINCT cs.cs_order_number) > 5
)
SELECT
    i_item_id,
    i_product_name,
    cc_name,
    w_warehouse_name,
    ib_lower_bound,
    ib_upper_bound,
    total_catalog_profit,
    total_web_profit,
    total_return_amount,
    (total_catalog_profit + total_web_profit - total_return_amount) AS overall_net_profit,
    catalog_orders,
    web_orders,
    return_tickets,
    RANK() OVER (PARTITION BY cc_name ORDER BY (total_catalog_profit + total_web_profit - total_return_amount) DESC) AS profit_rank_by_cc,
    ROW_NUMBER() OVER (ORDER BY (total_catalog_profit + total_web_profit - total_return_amount) DESC) AS global_profit_rank,
    CASE
        WHEN total_return_amount > 500 THEN 'High Returns'
        WHEN total_return_amount > 0 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_severity
FROM agg_data
ORDER BY global_profit_rank
LIMIT 100
