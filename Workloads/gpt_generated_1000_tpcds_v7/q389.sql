WITH
    cs AS (
        SELECT
            i.i_item_id AS product_id,
            i.i_product_name AS product_name,
            td.t_hour AS sale_hour,
            cd.cd_gender AS gender,
            hd.hd_income_band_sk AS income_band,
            w.w_warehouse_name AS warehouse_name,
            cs.cs_net_profit AS net_profit,
            'catalog' AS source
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE i.i_wholesale_cost > 10
          AND w.w_gmt_offset = -5.00
          AND td.t_hour BETWEEN 9 AND 17
          AND cd.cd_gender = 'M'
          AND hd.hd_income_band_sk = 2
    ),
    ss AS (
        SELECT
            i.i_item_id AS product_id,
            i.i_product_name AS product_name,
            td.t_hour AS sale_hour,
            cd.cd_gender AS gender,
            hd.hd_income_band_sk AS income_band,
            CAST(NULL AS varchar) AS warehouse_name,
            ss.ss_net_profit AS net_profit,
            'store' AS source
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE i.i_wholesale_cost > 10
          AND td.t_hour BETWEEN 9 AND 17
          AND cd.cd_gender = 'M'
          AND (r.r_reason_desc LIKE '%damage%' OR r.r_reason_desc IS NULL)
    ),
    ws AS (
        SELECT
            i.i_item_id AS product_id,
            i.i_product_name AS product_name,
            td.t_hour AS sale_hour,
            cd.cd_gender AS gender,
            hd.hd_income_band_sk AS income_band,
            w.w_warehouse_name AS warehouse_name,
            ws.ws_net_profit AS net_profit,
            'web' AS source
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        WHERE i.i_wholesale_cost > 10
          AND w.w_gmt_offset = -5.00
          AND td.t_hour BETWEEN 9 AND 17
          AND cd.cd_gender = 'M'
          AND we.web_state = 'CA'
    ),
    combined AS (
        SELECT * FROM cs
        UNION ALL
        SELECT * FROM ss
        UNION ALL
        SELECT * FROM ws
    )
SELECT
    product_id,
    product_name,
    sale_hour,
    gender,
    income_band,
    warehouse_name,
    source,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY net_profit DESC) AS profit_rank,
    CASE
        WHEN net_profit > 1000 THEN 'High'
        WHEN net_profit > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM combined
ORDER BY net_profit DESC
LIMIT 100
