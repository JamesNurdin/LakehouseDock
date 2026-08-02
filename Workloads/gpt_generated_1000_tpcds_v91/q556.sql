WITH cat_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        d.d_date,
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_customer_id,
        p.p_promo_id,
        cp.cp_catalog_page_number,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn_customer_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1998
      AND cs.cs_quantity > 1
      AND p.p_discount_active = 'Y'
    GROUP BY
        cs.cs_sold_date_sk,
        d.d_date,
        cs.cs_bill_customer_sk,
        c.c_customer_id,
        p.p_promo_id,
        cp.cp_catalog_page_number
),
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        d.d_date,
        ss.ss_customer_sk AS customer_sk,
        c.c_customer_id,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn_customer_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1998
      AND ss.ss_quantity > 1
      AND p.p_discount_active = 'Y'
    GROUP BY
        ss.ss_sold_date_sk,
        d.d_date,
        ss.ss_customer_sk,
        c.c_customer_id,
        p.p_promo_id
),
combined_sales AS (
    SELECT
        date_sk,
        d_date,
        customer_sk,
        c_customer_id,
        p_promo_id,
        'catalog' AS sale_type,
        sales_amount,
        net_profit,
        transaction_count,
        rn_customer_sales
    FROM cat_sales
    UNION ALL
    SELECT
        date_sk,
        d_date,
        customer_sk,
        c_customer_id,
        p_promo_id,
        'store' AS sale_type,
        sales_amount,
        net_profit,
        transaction_count,
        rn_customer_sales
    FROM store_sales_agg
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk AS date_sk,
        d.d_date,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
    GROUP BY inv.inv_date_sk, d.d_date
),
store_returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        d.d_date,
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 1998
    GROUP BY sr.sr_returned_date_sk, d.d_date, sr.sr_customer_sk
),
customer_latest_page AS (
    SELECT
        c.c_customer_sk,
        wp_latest.wp_web_page_id,
        wp_latest.wp_access_date_sk
    FROM customer c
    CROSS JOIN LATERAL (
        SELECT wp.wp_web_page_id, wp.wp_access_date_sk
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
        ORDER BY wp.wp_access_date_sk DESC
        LIMIT 1
    ) wp_latest
),
website_info AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_open_date_sk,
        d.d_year,
        d.d_date
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
),
cube_agg AS (
    SELECT
        d.d_year,
        cs.sale_type,
        cs.p_promo_id,
        SUM(cs.sales_amount) AS cube_sales_amount,
        SUM(cs.net_profit) AS cube_net_profit
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    GROUP BY CUBE (d.d_year, cs.sale_type, cs.p_promo_id)
),
final_agg AS (
    SELECT
        cs.date_sk,
        d.d_date,
        cs.customer_sk,
        c.c_customer_id,
        cs.p_promo_id,
        cs.sale_type,
        cs.sales_amount,
        cs.net_profit,
        cs.transaction_count,
        CASE
            WHEN cs.sales_amount > 100000 THEN 'High'
            WHEN cs.sales_amount > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        ia.total_inventory_qty,
        ra.total_return_amt,
        wp.wp_web_page_id,
        wp.wp_access_date_sk,
        wi.web_name,
        ROW_NUMBER() OVER (PARTITION BY cs.customer_sk ORDER BY cs.sales_amount DESC) AS rn_customer_total,
        ca.cube_sales_amount,
        ca.cube_net_profit,
        d.d_year
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN inventory_agg ia ON cs.date_sk = ia.date_sk
    LEFT JOIN store_returns_agg ra ON cs.date_sk = ra.date_sk AND cs.customer_sk = ra.customer_sk
    LEFT JOIN customer_latest_page wp ON cs.customer_sk = wp.c_customer_sk
    LEFT JOIN website_info wi ON cs.date_sk = wi.web_open_date_sk
    LEFT JOIN cube_agg ca ON d.d_year = ca.d_year
                           AND cs.sale_type = ca.sale_type
                           AND cs.p_promo_id = ca.p_promo_id
    WHERE cs.sales_amount IS NOT NULL
      AND cs.transaction_count > 0
      AND cs.rn_customer_sales = 1
)
SELECT DISTINCT
    fa.c_customer_id,
    fa.d_date,
    fa.sale_type,
    fa.sales_amount,
    fa.net_profit,
    fa.transaction_count,
    fa.sales_category,
    fa.wp_web_page_id,
    fa.rn_customer_total,
    fa.cube_sales_amount,
    fa.cube_net_profit,
    fa.d_year,
    fa.web_name,
    (SELECT SUM(sr.sr_return_amt)
     FROM store_returns sr
     WHERE sr.sr_customer_sk = fa.customer_sk) AS total_return_amount_for_customer
FROM final_agg fa
ORDER BY
    fa.sales_amount DESC,
    fa.c_customer_id
LIMIT 100
