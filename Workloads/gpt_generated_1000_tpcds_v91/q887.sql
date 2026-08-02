WITH
    store_sales_data AS (
        SELECT
            'store' AS channel,
            i.i_category,
            ss.ss_ext_sales_price AS sales_price,
            ss.ss_ext_discount_amt AS discount_amt,
            ss.ss_net_profit AS net_profit,
            COALESCE(sr.sr_return_amt, 0) AS return_amt,
            COALESCE(sr.sr_net_loss, 0) AS net_loss,
            ss.ss_quantity AS quantity,
            COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
            td.t_hour
        FROM time_dim td
        JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        LEFT JOIN store_returns sr
            ON sr.sr_return_time_sk = td.t_time_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN item i
            ON i.i_item_sk = ss.ss_item_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN promotion p
            ON p.p_promo_sk = ss.ss_promo_sk
        JOIN customer c
            ON c.c_customer_sk = ss.ss_customer_sk
        JOIN customer_demographics cd
            ON cd.cd_demo_sk = ss.ss_cdemo_sk
        WHERE td.t_hour = 12
          AND i.i_brand = 'Brand#12'
          AND ss.ss_quantity > 5
    ),
    catalog_and_web AS (
        SELECT
            'catalog' AS channel,
            i.i_category,
            cs.cs_ext_sales_price AS sales_price,
            cs.cs_ext_discount_amt AS discount_amt,
            cs.cs_net_profit AS net_profit,
            0 AS return_amt,
            0 AS net_loss,
            cs.cs_quantity AS quantity,
            0 AS return_quantity,
            td.t_hour
        FROM time_dim td
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN item i
            ON i.i_item_sk = cs.cs_item_sk
        LEFT JOIN promotion p
            ON p.p_promo_sk = cs.cs_promo_sk
        LEFT JOIN ship_mode sm
            ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        LEFT JOIN call_center cc
            ON cc.cc_call_center_sk = cs.cs_call_center_sk
        LEFT JOIN catalog_page cp
            ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
        LEFT JOIN customer c
            ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN customer_demographics cd
            ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        WHERE td.t_hour = 12
          AND i.i_brand = 'Brand#12'
          AND cs.cs_quantity > 5
        UNION ALL
        SELECT
            'web' AS channel,
            i.i_category,
            ws.ws_ext_sales_price AS sales_price,
            ws.ws_ext_discount_amt AS discount_amt,
            ws.ws_net_profit AS net_profit,
            COALESCE(wr.wr_return_amt, 0) AS return_amt,
            COALESCE(wr.wr_net_loss, 0) AS net_loss,
            ws.ws_quantity AS quantity,
            COALESCE(wr.wr_return_quantity, 0) AS return_quantity,
            td.t_hour
        FROM time_dim td
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        LEFT JOIN web_returns wr
            ON wr.wr_returned_time_sk = td.t_time_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
        JOIN item i
            ON i.i_item_sk = ws.ws_item_sk
        LEFT JOIN promotion p
            ON p.p_promo_sk = ws.ws_promo_sk
        LEFT JOIN ship_mode sm
            ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
        LEFT JOIN web_page wp
            ON wp.wp_web_page_sk = ws.ws_web_page_sk
        LEFT JOIN customer c
            ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN customer_demographics cd
            ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        WHERE td.t_hour = 12
          AND i.i_brand = 'Brand#12'
          AND ws.ws_quantity > 5
    ),
    raw_union AS (
        SELECT
            channel,
            i_category,
            sales_price,
            discount_amt,
            net_profit,
            return_amt,
            net_loss,
            quantity,
            return_quantity,
            t_hour
        FROM store_sales_data
        UNION DISTINCT
        SELECT
            channel,
            i_category,
            sales_price,
            discount_amt,
            net_profit,
            return_amt,
            net_loss,
            quantity,
            return_quantity,
            t_hour
        FROM catalog_and_web
    )
SELECT
    channel,
    i_category,
    SUM(sales_price) AS total_sales,
    SUM(return_amt) AS total_returns,
    SUM(net_profit) AS total_profit,
    (SELECT AVG(i3.i_current_price) FROM item i3 WHERE i3.i_category = i_category) AS avg_category_price
FROM raw_union
GROUP BY GROUPING SETS ((channel, i_category), (channel), (i_category), ())
ORDER BY total_sales DESC
LIMIT 100
