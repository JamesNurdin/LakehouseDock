WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2002
      AND i.i_current_price BETWEEN 20 AND 100
      AND ca.ca_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND p.p_channel_catalog = 'N'
      AND w.w_warehouse_id IN ('W001', 'W002')
      AND inv.inv_quantity_on_hand > 0
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        cs.cs_promo_sk
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.i_item_id,
    a.i_product_name,
    a.catalog_sales_amount,
    a.web_sales_amount,
    (a.catalog_sales_amount + a.web_sales_amount) AS total_sales,
    (a.catalog_quantity + a.web_quantity) AS total_quantity,
    (a.catalog_profit + a.web_profit) AS total_profit,
    RANK() OVER (PARTITION BY a.d_month_seq ORDER BY (a.catalog_sales_amount + a.web_sales_amount) DESC) AS sales_rank,
    (
        SELECT AVG(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
          AND p2.p_promo_sk = a.cs_promo_sk
    ) AS avg_active_promo_cost
FROM agg a
ORDER BY a.d_year, a.d_month_seq, sales_rank
LIMIT 100
