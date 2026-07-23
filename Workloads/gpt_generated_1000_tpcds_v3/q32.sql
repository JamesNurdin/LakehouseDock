WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_item_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_discount_amt) AS total_discount
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_sales_price > 100
    GROUP BY cs_call_center_sk, cs_item_sk
),
returns_agg AS (
    SELECT
        wr_item_sk,
        wr_reason_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        SUM(wr_return_tax) AS total_return_tax
    FROM web_returns
    WHERE wr_return_tax > 10
      AND wr_return_ship_cost > 50
    GROUP BY wr_item_sk, wr_reason_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    sales_agg.total_net_paid,
    sales_agg.total_quantity,
    returns_agg.total_return_amt,
    returns_agg.return_cnt,
    (sales_agg.total_net_paid - returns_agg.total_return_amt) AS net_profit_adjusted
FROM sales_agg
JOIN call_center cc
    ON sales_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON sales_agg.cs_item_sk = i.i_item_sk
JOIN returns_agg
    ON returns_agg.wr_item_sk = i.i_item_sk
JOIN reason r
    ON returns_agg.wr_reason_sk = r.r_reason_sk
WHERE cc.cc_tax_percentage >= 0.02
  AND cc.cc_hours = '8AM-4PM'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND i.i_brand = 'Brand#12'
  AND i.i_color = 'Red'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    sales_agg.total_net_paid,
    sales_agg.total_quantity,
    returns_agg.total_return_amt,
    returns_agg.return_cnt
HAVING (sales_agg.total_net_paid - returns_agg.total_return_amt) > 0
ORDER BY (sales_agg.total_net_paid - returns_agg.total_return_amt) DESC
LIMIT 100
