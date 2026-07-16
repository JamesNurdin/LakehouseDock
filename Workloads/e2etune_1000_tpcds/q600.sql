WITH sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        sum(cs.cs_ext_sales_price) AS total_sales_amount,
        sum(cs.cs_quantity) AS total_sales_quantity,
        sum(cs.cs_net_profit) AS total_sales_profit,
        sum(cs.cs_ext_discount_amt) AS total_discount_amount,
        count(*) AS sales_txn_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk, cs.cs_promo_sk, cs.cs_order_number
),
returns AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        sum(cr.cr_return_quantity) AS total_return_quantity,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_net_loss) AS total_net_loss,
        count(*) AS return_txn_cnt
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY cr.cr_call_center_sk, cr.cr_item_sk, cr.cr_order_number
),
sales_returns AS (
    SELECT
        s.cs_call_center_sk,
        s.cs_item_sk,
        s.cs_promo_sk,
        s.cs_order_number,
        s.total_sales_amount,
        s.total_sales_quantity,
        s.total_sales_profit,
        s.total_discount_amount,
        s.sales_txn_cnt,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        COALESCE(r.return_txn_cnt, 0) AS return_txn_cnt
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_call_center_sk = r.cr_call_center_sk
        AND s.cs_item_sk = r.cr_item_sk
        AND s.cs_order_number = r.cr_order_number
),
agg AS (
    SELECT
        cc.cc_division_name,
        i.i_category,
        i.i_brand,
        sum(sr.total_sales_amount) AS sum_sales_amount,
        sum(sr.total_sales_quantity) AS sum_sales_qty,
        sum(sr.total_sales_profit) AS sum_sales_profit,
        sum(sr.total_discount_amount) AS sum_discount_amt,
        sum(sr.total_return_quantity) AS sum_return_qty,
        sum(sr.total_return_amount) AS sum_return_amt,
        sum(sr.total_net_loss) AS sum_net_loss,
        (sum(sr.total_sales_profit) - sum(sr.total_net_loss)) AS net_contribution,
        CASE WHEN sum(sr.total_sales_amount) > 0 THEN sum(sr.total_discount_amount) / sum(sr.total_sales_amount) ELSE 0 END AS avg_discount_rate,
        count(DISTINCT sr.cs_promo_sk) AS distinct_promos,
        sum(p.p_cost) AS total_promo_cost
    FROM sales_returns sr
    JOIN call_center cc ON sr.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON sr.cs_item_sk = i.i_item_sk
    JOIN promotion p ON sr.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_class = 'large'
      AND p.p_discount_active = 'Y'
    GROUP BY cc.cc_division_name, i.i_category, i.i_brand
    HAVING sum(sr.total_sales_amount) > 10000
)
SELECT
    division,
    category,
    brand,
    sum_sales_amount,
    sum_sales_qty,
    sum_sales_profit,
    sum_discount_amt,
    sum_return_qty,
    sum_return_amt,
    sum_net_loss,
    net_contribution,
    avg_discount_rate,
    distinct_promos,
    total_promo_cost,
    RANK() OVER (PARTITION BY division ORDER BY net_contribution DESC) AS category_rank
FROM (
    SELECT
        cc_division_name AS division,
        i_category AS category,
        i_brand AS brand,
        sum_sales_amount,
        sum_sales_qty,
        sum_sales_profit,
        sum_discount_amt,
        sum_return_qty,
        sum_return_amt,
        sum_net_loss,
        net_contribution,
        avg_discount_rate,
        distinct_promos,
        total_promo_cost
    FROM agg
) a
ORDER BY net_contribution DESC
LIMIT 20
