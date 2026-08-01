WITH
    filtered_catalog_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_ext_sales_price,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_promo_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 1
          AND cs.cs_net_paid > 1000
          AND cs.cs_sold_date_sk IN (
              SELECT d.d_date_sk
              FROM date_dim d
              WHERE d.d_year = 2001
          )
    ),
    joined_base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_ext_sales_price,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_promo_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cc.cc_name,
            cp.cp_description,
            p.p_promo_name,
            p.p_discount_active,
            d_sold.d_year,
            d_sold.d_month_seq,
            d_sold.d_date,
            c.c_customer_sk AS customer_sk,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            hd.hd_buy_potential,
            ca.ca_city,
            ss.ss_quantity AS ss_quantity,
            s.s_store_name,
            ws.web_name,
            r.r_reason_desc,
            wp.wp_url
        FROM filtered_catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
           AND ss.ss_customer_sk = c.c_customer_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d_sold.d_date_sk
           AND wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_site ws
            ON ws.web_open_date_sk = d_sold.d_date_sk
        WHERE NOT EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = p.p_promo_sk
              AND p2.p_channel_email = 'Y'
        )
    ),
    agg_sales AS (
        SELECT
            d_year,
            d_month_seq,
            c_first_name,
            c_last_name,
            s_store_name,
            web_name,
            p_discount_active,
            customer_sk,
            d_date,
            SUM(cs_net_paid) AS total_net_paid,
            SUM(cs_ext_sales_price) AS total_sales
        FROM joined_base
        GROUP BY
            d_year,
            d_month_seq,
            c_first_name,
            c_last_name,
            s_store_name,
            web_name,
            p_discount_active,
            customer_sk,
            d_date
    )
SELECT
    d_year,
    d_month_seq,
    c_first_name,
    c_last_name,
    s_store_name,
    web_name,
    CASE WHEN p_discount_active = 'Y' THEN 'Active Promo' ELSE 'Inactive Promo' END AS promo_status,
    total_net_paid,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank,
    SUM(total_net_paid) OVER (PARTITION BY customer_sk ORDER BY d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_net_paid
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
