WITH sales_summary AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_department,
        r.r_reason_desc,
        hd_cs.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS sum_catalog_sales,
        SUM(ss.ss_net_paid_inc_tax) AS sum_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS sum_web_sales,
        SUM(wr.wr_net_loss) AS sum_returns_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
        MIN(ss.ss_net_paid_inc_tax) AS min_store_paid,
        MAX(ws.ws_net_paid_inc_tax) AS max_web_paid
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
       AND ss.ss_hdemo_sk = hd_cs.hd_demo_sk
       AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_bill_hdemo_sk = hd_cs.hd_demo_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
       AND wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_catalog_number IN (8, 15)
      AND p.p_promo_name LIKE '%Discount%'
      AND hd_cs.hd_buy_potential = '500-1000'
      AND r.r_reason_desc = 'Customer not home'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND ss.ss_net_paid_inc_tax > 100.00
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY p.p_promo_id, p.p_promo_name, cp.cp_department, r.r_reason_desc, hd_cs.hd_buy_potential
)
SELECT
    s.p_promo_id,
    s.p_promo_name,
    s.cp_department,
    s.r_reason_desc,
    s.hd_buy_potential,
    s.sum_catalog_sales,
    s.sum_store_sales,
    s.sum_web_sales,
    s.sum_returns_loss,
    s.distinct_customers,
    s.avg_catalog_discount,
    s.min_store_paid,
    s.max_web_paid,
    (s.sum_catalog_sales + s.sum_store_sales + s.sum_web_sales) AS total_sales,
    SUM(s.sum_catalog_sales + s.sum_store_sales + s.sum_web_sales) OVER (PARTITION BY s.p_promo_id) AS promo_total_sales,
    RANK() OVER (PARTITION BY s.p_promo_id ORDER BY (s.sum_catalog_sales + s.sum_store_sales + s.sum_web_sales) DESC) AS sales_rank_within_promo,
    (SELECT SUM(s2.sum_catalog_sales + s2.sum_store_sales + s2.sum_web_sales)
     FROM sales_summary s2
     WHERE s2.cp_department = s.cp_department) AS dept_total_sales
FROM sales_summary s
ORDER BY total_sales DESC
LIMIT 100
