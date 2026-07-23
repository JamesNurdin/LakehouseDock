WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_type,
        i.i_brand,
        i.i_color,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        SUM(ss.ss_net_paid) AS total_ss_net_paid,
        AVG(cs.cs_ext_tax) AS avg_cs_ext_tax,
        COUNT(*) AS transaction_cnt,
        MIN(i.i_current_price) AS min_item_price,
        MAX(ss.ss_list_price) AS max_store_list_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
      AND cc.cc_state = 'CA'
      AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
      AND cp.cp_department = 'Electronics'
      AND cs.cs_list_price > 50.00
      AND ss.ss_net_paid_inc_tax > 0
      AND i.i_brand = 'Brand#12'
      AND i.i_color = 'Red'
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cp.cp_type, i.i_brand, i.i_color
)
SELECT
    cc_name,
    cp_type,
    i_brand,
    i_color,
    total_cs_net_paid,
    total_ss_net_paid,
    avg_cs_ext_tax,
    transaction_cnt,
    min_item_price,
    max_store_list_price,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_cs_net_profit,
    RANK() OVER (ORDER BY (total_cs_net_paid + total_ss_net_paid) DESC) AS revenue_rank
FROM sales_agg
ORDER BY revenue_rank
LIMIT 100
