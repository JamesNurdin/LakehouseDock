WITH inv_w AS (
    SELECT
        inv.inv_date_sk AS d_date_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        w.w_gmt_offset
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
promo_d AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_start_date_sk AS d_date_sk,
        d.d_date AS promo_start_date,
        p.p_end_date_sk,
        d_end.d_date AS promo_end_date
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
),
invpromo AS (
    SELECT
        COALESCE(i.d_date_sk, p.d_date_sk) AS d_date_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        i.w_warehouse_sk,
        i.w_warehouse_name,
        i.w_state,
        i.w_gmt_offset,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.promo_start_date,
        p.promo_end_date
    FROM inv_w i
    FULL OUTER JOIN promo_d p
        ON i.d_date_sk = p.d_date_sk
),
sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        SUM(ss.ss_net_profit) AS total_net_profit,
        MAX(ip.inv_quantity_on_hand) AS inventory_quantity,
        MAX(ip.w_warehouse_name) AS warehouse_name,
        MAX(ip.w_gmt_offset) AS warehouse_gmt_offset,
        MAX(p.p_promo_name) AS promo_name,
        MAX(cp.cp_catalog_number) AS catalog_number,
        MAX(c.c_first_name) AS first_customer_name,
        MAX(ca.ca_city) AS customer_city,
        MAX(cd.cd_education_status) AS customer_education_status
    FROM invpromo ip
    JOIN date_dim d ON ip.d_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2002
        AND s.s_state IN ('CA', 'TX')
        AND ip.w_gmt_offset >= 0
        AND ip.inv_quantity_on_hand > 0
        AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
        AND (sr.sr_return_amt IS NULL OR sr.sr_return_amt > 50)
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_date
    HAVING
        SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    d_date,
    total_sales,
    total_returns,
    total_net_profit,
    inventory_quantity,
    warehouse_name,
    warehouse_gmt_offset,
    promo_name,
    catalog_number,
    first_customer_name,
    customer_city,
    customer_education_status,
    CASE WHEN total_returns > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_profit DESC) AS state_store_rank,
    RANK() OVER (ORDER BY total_net_profit DESC) AS global_store_rank
FROM sales_agg
ORDER BY global_store_rank
LIMIT 100
