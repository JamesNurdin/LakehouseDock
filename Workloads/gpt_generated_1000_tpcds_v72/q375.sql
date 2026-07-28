/*
Goal: Analyze combined sales and return performance for the year 2001, focusing on California stores and a specific brand, while filtering by active promotions, call center location, and damaged return reasons. The query joins all 15 selected TPC‑DS tables, applies multiple selective predicates, uses a DISTINCT count, and aggregates with GROUPING SETS.
*/
WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_amt AS wr_return_amt,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_category,
        i.i_brand,
        p.p_discount_active,
        p.p_promo_id,
        s.s_state,
        cc.cc_state,
        r.r_reason_desc
    FROM store_sales ss
    JOIN date_dim d                ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t                ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    d_year,
    s_state,
    i_category,
    COUNT(DISTINCT p_promo_id)                         AS distinct_promos,
    SUM(ss_ext_sales_price)                            AS store_sales_total,
    SUM(cs_ext_sales_price)                            AS catalog_sales_total,
    SUM(wr_return_amt)                                 AS returns_total,
    AVG(ss_net_profit)                                 AS avg_store_profit,
    MAX(cs_net_profit)                                 AS max_catalog_profit,
    MIN(wr_return_quantity)                           AS min_return_qty
FROM joined
WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND t_hour BETWEEN 9 AND 17
  AND i_brand = 'Brand#23'
  AND p_discount_active = 'Y'
  AND s_state = 'CA'
  AND cc_state = 'TX'
  AND r_reason_desc LIKE '%damaged%'
GROUP BY GROUPING SETS (
    (d_year, s_state, i_category),
    (d_year, s_state),
    (d_year)
)
ORDER BY d_year DESC, s_state, i_category
LIMIT 100
