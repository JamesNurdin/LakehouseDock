WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        d_sales.d_date,
        p.p_promo_name,
        cc.cc_name AS call_center_name,
        ws.web_name AS web_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_sales_price) AS avg_price
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE
        d_sales.d_year = 1998
        AND s.s_state = 'CA'
        AND i.i_category = 'Sports'
        AND p.p_discount_active = 'Y'
        AND cd.cd_credit_rating = 'Good'
        AND cc.cc_state = 'TX'
        AND t.t_hour BETWEEN 9 AND 17
        AND ss.ss_quantity > 1
    GROUP BY
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        d_sales.d_date,
        p.p_promo_name,
        cc.cc_name,
        ws.web_name
    HAVING
        SUM(ss.ss_ext_sales_price) > 1000
)
SELECT
    s_store_name,
    s_state,
    i_category,
    i_brand,
    d_date,
    total_sales,
    total_quantity,
    distinct_tickets,
    avg_price,
    call_center_name,
    web_name,
    RANK() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS sales_rank_state,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank,
    CASE
        WHEN total_sales > 5000 THEN 'High'
        WHEN total_sales > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category
FROM sales_agg
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
