WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk               AS sold_date_sk,
        ws.ws_sold_time_sk               AS sold_time_sk,
        ws.ws_item_sk                    AS item_sk,
        ws.ws_web_site_sk                AS web_site_sk,
        ws.ws_promo_sk                   AS promo_sk,
        ca_bill.ca_state                 AS bill_state,
        ca_ship.ca_state                 AS ship_state,
        i.i_brand                        AS brand,
        i.i_category                     AS category,
        p.p_discount_active              AS discount_active,
        SUM(ws.ws_ext_sales_price)       AS total_sales,
        SUM(ws.ws_ext_discount_amt)      AS total_discount,
        COUNT(*)                         AS order_cnt
    FROM web_sales ws
    JOIN time_dim td               ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i                    ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca_bill  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_site ws_site          ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws_site.web_rec_end_date >= DATE '2000-01-01'
      AND ws_site.web_rec_end_date <= DATE '2001-12-31'
      AND ca_bill.ca_location_type = 'single family'
      AND ca_ship.ca_location_type = 'apartment'
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND td.t_sub_shift = 'morning'
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ca_bill.ca_state,
        ca_ship.ca_state,
        i.i_brand,
        i.i_category,
        p.p_discount_active
)
SELECT
    s.sold_date_sk,
    s.bill_state,
    s.ship_state,
    s.brand,
    s.category,
    SUM(s.total_sales)       AS sum_sales,
    SUM(s.total_discount)    AS sum_discount,
    COUNT(*)                 AS grp_cnt,
    CASE WHEN SUM(s.total_sales) > 10000 THEN 'High' ELSE 'Low' END AS sales_level
FROM sales_agg s
WHERE s.total_sales > (SELECT AVG(total_sales) FROM sales_agg)
GROUP BY GROUPING SETS (
    (s.sold_date_sk, s.bill_state, s.ship_state, s.brand, s.category),
    (s.sold_date_sk, s.bill_state, s.ship_state, s.brand),
    (s.sold_date_sk, s.bill_state, s.ship_state),
    (s.sold_date_sk, s.bill_state),
    (s.sold_date_sk),
    ()
)
ORDER BY sum_sales DESC
LIMIT 100
