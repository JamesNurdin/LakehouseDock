WITH joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cc.cc_state,
        cp.cp_department,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        td.t_hour,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND ib.ib_upper_bound > 50000
      AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        i_item_id,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_quantity * cs_net_paid) / NULLIF(SUM(cs_quantity), 0) AS avg_price,
        lr.total_returns
    FROM joined
    CROSS JOIN LATERAL (
        SELECT SUM(wr_return_amt) AS total_returns
        FROM web_returns wr
        WHERE wr.wr_item_sk = joined.cs_item_sk
    ) lr
    GROUP BY i_item_id, lr.total_returns
    HAVING SUM(cs_net_paid) > 1000
)
SELECT i_item_id, total_sales, total_returns
FROM agg
WHERE total_sales > 5000

UNION DISTINCT

SELECT i_item_id, total_sales, total_returns
FROM agg
WHERE total_returns > 2000
LIMIT 100
