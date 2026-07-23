WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        MIN(ss.ss_net_paid) AS min_store_sale,
        MAX(ss.ss_net_paid) AS max_store_sale
    FROM tpcds.date_dim d
    INNER JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    INNER JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 1998
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'TX'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name, s.s_state, i.i_category, i.i_brand, r.r_reason_desc
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    s_state,
    i_category,
    i_brand,
    r_reason_desc,
    total_store_sales,
    total_catalog_sales,
    total_returns,
    total_inventory,
    avg_promo_cost,
    num_transactions,
    min_store_sale,
    max_store_sale,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_store_sales DESC) AS rn_state_sales_rank
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
