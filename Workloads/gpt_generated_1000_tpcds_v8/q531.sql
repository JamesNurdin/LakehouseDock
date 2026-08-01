WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand > 0
),
base_join AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_category,
        w.w_warehouse_name,
        s.s_store_name,
        s.s_store_sk AS store_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        (cs.cs_ext_sales_price - cs.cs_ext_discount_amt) AS net_sales,
        cr.cr_return_amount,
        sr.sr_net_loss,
        wr.wr_net_loss,
        p.p_discount_active,
        cc.cc_class,
        cp.cp_type,
        r.r_reason_desc,
        hd.hd_buy_potential,
        td.t_hour
    FROM sampled_inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE d.d_year = 2000
      AND w.w_county = 'San Miguel County'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND cc.cc_class = 'A'
      AND cp.cp_type = 'catalog'
),
category_agg AS (
    SELECT
        d_year,
        i_item_id,
        i_category,
        w_warehouse_name,
        s_store_name,
        store_sk,
        SUM(net_sales) AS total_net_sales,
        AVG(cs_net_profit) AS avg_net_profit,
        COUNT(DISTINCT r_reason_desc) AS distinct_reason_cnt,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(net_sales) DESC) AS category_sales_rank
    FROM base_join
    GROUP BY d_year, i_item_id, i_category, w_warehouse_name, s_store_name, store_sk
    HAVING SUM(net_sales) > 1000
)
SELECT
    ca.d_year,
    ca.i_item_id,
    ca.i_category,
    ca.w_warehouse_name,
    ca.s_store_name,
    ca.total_net_sales,
    ca.avg_net_profit,
    ca.distinct_reason_cnt,
    ca.category_sales_rank,
    lr.returns_cnt
FROM category_agg ca
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS returns_cnt
    FROM store_returns sr
    WHERE sr.sr_store_sk = ca.store_sk
) lr
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = ca.store_sk
      AND sr2.sr_net_loss > 0
)
  AND lr.returns_cnt > 5
ORDER BY ca.total_net_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
