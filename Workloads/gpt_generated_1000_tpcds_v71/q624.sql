/*
Goal: Identify call centers and catalog departments that generate high average sales and profit, filtering by high‑income households, California warehouses, and active promotions. The query aggregates sales per order, joins all nine TPC‑DS tables in a left‑deep chain, applies multiple predicates, uses a UNION‑based IN subquery, a scalar subquery, and a final HAVING filter, then orders the results.
*/
WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS line_count
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_sales_price > 100
    GROUP BY
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk
),
joined AS (
    SELECT
        sa.cs_order_number,
        sa.total_sales,
        sa.total_profit,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        cc.cc_name,
        cp.cp_department,
        w.w_city,
        w.w_state,
        p.p_promo_name,
        cr.cr_return_amount,
        r.r_reason_desc
    FROM sales_agg sa
    JOIN customer c
        ON sa.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON sa.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON sa.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON sa.cs_order_number = cr.cr_order_number
       AND sa.cs_bill_customer_sk = cr.cr_refunded_customer_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_gmt_offset > -5
      AND hd.hd_buy_potential = '>10000'
      AND w.w_state = 'CA'
      AND cc.cc_name IN (
          SELECT cc_name FROM (
              SELECT cc_name FROM call_center WHERE cc_employees > 100
              UNION
              SELECT cc_name FROM call_center WHERE cc_employees < 50
          ) AS cc_union
      )
),
final_agg AS (
    SELECT
        j.cc_name,
        j.cp_department,
        AVG(j.total_sales) AS avg_sales,
        SUM(j.total_profit) AS profit_sum,
        COUNT(DISTINCT j.cs_order_number) AS orders
    FROM joined j
    GROUP BY j.cc_name, j.cp_department
    HAVING SUM(j.total_profit) > 10000
)
SELECT
    fa.cc_name,
    fa.cp_department,
    fa.avg_sales,
    fa.profit_sum,
    fa.orders
FROM final_agg fa
WHERE fa.avg_sales > (
    SELECT AVG(avg_sales) FROM final_agg
)
ORDER BY fa.profit_sum DESC
LIMIT 100
