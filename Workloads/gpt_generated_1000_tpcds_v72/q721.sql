WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category_id,
        i.i_brand,
        cc.cc_state,
        p.p_discount_active,
        p.p_promo_name,
        inv.inv_quantity_on_hand,
        -- Sales from catalog and web channels
        COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) AS total_sales,
        -- Returns (if any)
        COALESCE(wr.wr_return_amt, 0) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc                 ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws              ON ws.ws_item_sk = cs.cs_item_sk
                                        AND ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr           ON wr.wr_item_sk = cs.cs_item_sk
                                        AND wr.wr_order_number = cs.cs_order_number
    JOIN inventory inv                  ON inv.inv_item_sk = i.i_item_sk
                                        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_category_id = 5
      AND i.i_size = 'large'
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 100
      AND p.p_promo_name LIKE '%Summer%'
),
agg_data AS (
    SELECT
        d_year,
        d_month_seq,
        i_category_id,
        i_brand,
        SUM(total_sales)   AS sum_total_sales,
        SUM(total_returns) AS sum_total_returns,
        COUNT(*)           AS txn_count
    FROM joined_data
    GROUP BY ROLLUP (d_year, d_month_seq, i_category_id, i_brand)
)
SELECT
    d_year,
    d_month_seq,
    i_category_id,
    i_brand,
    sum_total_sales,
    sum_total_returns,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY sum_total_sales DESC) AS rank_by_category
FROM agg_data
ORDER BY d_year NULLS LAST,
         d_month_seq NULLS LAST,
         i_category_id NULLS LAST,
         i_brand NULLS LAST
LIMIT 100
