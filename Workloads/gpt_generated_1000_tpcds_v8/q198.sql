-- goal: compare aggregated sales from Store and Catalog channels against Web returns, showing subtotals by channel, location, item and hour
WITH
-- Store sales aggregation (includes inventory and possible store returns via left joins)
store_sales_agg AS (
    SELECT
        'Store' AS channel,
        s.s_store_name AS location,
        i.i_item_id   AS item_id,
        t.t_hour      AS hour,
        ss.ss_net_paid   AS sales,
        ss.ss_quantity   AS quantity
    FROM store_sales ss
    JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
    JOIN item i                      ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t                  ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN inventory inv          ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr       ON sr.sr_ticket_number = ss.ss_ticket_number
                                      AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer c                  ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd    ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd   ON ss.ss_hdemo_sk = hd.hd_demo_sk
),

-- Catalog sales aggregation (includes possible catalog returns via left join)
catalog_sales_agg AS (
    SELECT
        'Catalog' AS channel,
        cc.cc_name   AS location,
        i2.i_item_id AS item_id,
        t2.t_hour    AS hour,
        cs.cs_net_paid   AS sales,
        cs.cs_quantity   AS quantity
    FROM catalog_sales cs
    JOIN call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i2                      ON cs.cs_item_sk = i2.i_item_sk
    JOIN time_dim t2                  ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c2                  ON cs.cs_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2    ON cs.cs_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2   ON cs.cs_bill_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = cs.cs_item_sk
),

-- Web returns (used to be subtracted from the sales set)
web_returns_agg AS (
    SELECT
        'WebReturn' AS channel,
        ws_site.web_name AS location,
        i3.i_item_id   AS item_id,
        t3.t_hour      AS hour,
        wr.wr_return_amt   AS sales,
        wr.wr_return_quantity AS quantity
    FROM web_returns wr
    JOIN web_sales ws               ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site ws_site           ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i3                    ON wr.wr_item_sk = i3.i_item_sk
    JOIN time_dim t3                ON wr.wr_returned_time_sk = t3.t_time_sk
    JOIN ship_mode sm3              ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
    JOIN customer c3                ON wr.wr_refunded_customer_sk = c3.c_customer_sk
    JOIN customer_demographics cd3  ON wr.wr_refunded_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON wr.wr_refunded_hdemo_sk = hd3.hd_demo_sk
),

-- Union of Store and Catalog sales
combined_sales AS (
    SELECT channel, location, item_id, hour, sales, quantity FROM store_sales_agg
    UNION ALL
    SELECT channel, location, item_id, hour, sales, quantity FROM catalog_sales_agg
),

-- Remove rows that appear as Web returns
final_set AS (
    SELECT channel, location, item_id, hour, sales, quantity FROM combined_sales
    EXCEPT
    SELECT channel, location, item_id, hour, sales, quantity FROM web_returns_agg
)
SELECT
    channel,
    location,
    item_id,
    hour,
    SUM(sales)    AS total_sales,
    SUM(quantity) AS total_quantity
FROM final_set
GROUP BY GROUPING SETS (
    (channel, location, item_id, hour),
    (channel, location, item_id),
    (channel, location),
    (channel),
    ()
)
ORDER BY channel, location, item_id, hour
