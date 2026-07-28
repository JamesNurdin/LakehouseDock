WITH sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price
    FROM tpcds.web_sales ws
)
SELECT
    d_sold.d_year                              AS sales_year,
    i.i_category                               AS item_category,
    SUM(s.ws_net_profit)                       AS total_profit,
    AVG(s.ws_quantity)                         AS avg_quantity,
    COUNT(DISTINCT s.ws_order_number)          AS order_cnt,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status,
    SUM(inv.inv_quantity_on_hand)              AS total_inventory_on_sale_date,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM tpcds.web_sales ws2
        JOIN tpcds.date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
    )                                          AS avg_yearly_profit_all_items
FROM sales s
JOIN tpcds.date_dim d_sold      ON s.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship      ON s.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.item i               ON s.ws_item_sk = i.i_item_sk
JOIN tpcds.customer c           ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN tpcds.promotion p    ON s.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm        ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.web_page wp         ON s.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.inventory inv       ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2001 AND 2002               -- filter on year range
    AND c.c_preferred_cust_flag = 'Y'                -- preferred customers only
    AND ib.ib_upper_bound >= 80000                  -- higher‑income households
    AND sm.sm_type = 'AIR'                           -- ship mode filter
    AND cd.cd_credit_rating = 'Good'                -- credit rating filter
GROUP BY
    d_sold.d_year,
    i.i_category,
    p.p_discount_active
ORDER BY
    total_profit DESC
LIMIT 100
