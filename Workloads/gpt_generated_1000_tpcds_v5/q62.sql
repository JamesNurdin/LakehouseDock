WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_brand_id AS brand_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE td.t_hour BETWEEN 8 AND 17                                 -- business hours
      AND i.i_category = 'Electronics'                               -- filter category
      AND wsit.web_country = 'United States'                         -- US web sites
      AND p.p_discount_active = 'Y'                                 -- active promotions
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_quantity_on_hand > 0                 -- positive inventory
        )
    GROUP BY i.i_brand, i.i_brand_id
)
SELECT
    brand,
    brand_id,
    total_sales,
    total_profit,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    total_return_qty,
    total_return_qty / NULLIF(orders, 0) AS avg_return_qty_per_order
FROM sales_agg
WHERE total_sales > 10000                                            -- high‑volume brands
ORDER BY profit_margin DESC
LIMIT 20
