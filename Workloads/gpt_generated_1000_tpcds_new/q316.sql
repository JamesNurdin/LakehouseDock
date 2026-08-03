WITH
    agg_inventory AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    order_returns AS (
        SELECT cs.cs_order_number AS order_number
        FROM catalog_sales cs
        JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        WHERE cr.cr_return_amount > 100
    ),
    web_order_returns AS (
        SELECT ws.ws_order_number AS order_number
        FROM web_sales ws
        JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        WHERE wr.wr_return_amt > 50
    ),
    intersect_orders AS (
        SELECT order_number FROM order_returns
        INTERSECT
        SELECT order_number FROM web_order_returns
    )
SELECT *
FROM (
    SELECT
        d_sold.d_year,
        i.i_category,
        SUM(cs.cs_net_profit)                     AS total_net_profit,
        SUM(COALESCE(cr.cr_return_amount, 0))     AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number)        AS order_cnt,
        AVG(inv.total_on_hand)                    AS avg_inventory_on_hand,
        MIN(cc.cc_gmt_offset)                     AS min_gmt_offset,
        (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_avg_net_paid
    FROM catalog_sales cs
    JOIN agg_inventory inv ON cs.cs_item_sk = inv.inv_item_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND hd.hd_income_band_sk BETWEEN 5 AND 8
      AND cc.cc_state = 'TX'
      AND wp.wp_max_ad_count > 1
      AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
    GROUP BY d_sold.d_year, i.i_category

    UNION DISTINCT

    SELECT
        d_sold.d_year,
        i.i_category,
        SUM(ws.ws_net_profit)                     AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt, 0))        AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number)        AS order_cnt,
        AVG(inv.total_on_hand)                    AS avg_inventory_on_hand,
        MIN(cc.cc_gmt_offset)                     AS min_gmt_offset,
        (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_avg_net_paid
    FROM web_sales ws
    JOIN agg_inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sold.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND hd.hd_income_band_sk BETWEEN 5 AND 8
      AND wp.wp_max_ad_count > 1
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = ws.ws_order_number
              AND cr2.cr_return_amount > 200
        )
      AND ws.ws_order_number IN (SELECT order_number FROM intersect_orders)
    GROUP BY d_sold.d_year, i.i_category
) AS unified
LIMIT 100
