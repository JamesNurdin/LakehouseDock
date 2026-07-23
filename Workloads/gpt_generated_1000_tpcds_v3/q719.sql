WITH store_agg AS (
    SELECT
        d_ss.d_year AS year,
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS txn_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        MIN(ss.ss_ext_sales_price) AS min_sale,
        MAX(ss.ss_ext_sales_price) AS max_sale
    FROM store_sales ss
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_ss.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_ss.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year BETWEEN 2001 AND 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND i.inv_quantity_on_hand > 1000
    GROUP BY d_ss.d_year, p.p_promo_id
),
web_agg AS (
    SELECT
        d_ws.d_year AS year,
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS txn_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        MIN(ws.ws_ext_sales_price) AS min_sale,
        MAX(ws.ws_ext_sales_price) AS max_sale
    FROM web_sales ws
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer c2
        ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2
        ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN call_center cc2
        ON cc2.cc_open_date_sk = d_ws.d_date_sk
    JOIN inventory i2
        ON i2.inv_date_sk = d_ws.d_date_sk
    JOIN web_site ws_site
        ON ws_site.web_open_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year BETWEEN 2001 AND 2002
      AND t2.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND ws_site.web_country = 'United States'
      AND i2.inv_quantity_on_hand > 1000
    GROUP BY d_ws.d_year, p.p_promo_id
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY year, promo_id
