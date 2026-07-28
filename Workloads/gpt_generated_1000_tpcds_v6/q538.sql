WITH returns_raw AS (
    SELECT
        cr_item_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_item_sk, cr_call_center_sk
),
sales_agg AS (
    SELECT
        cc_sales.cc_name AS call_center_name,
        i_sales.i_category AS item_category,
        SUM(cs.cs_net_paid) AS total_sales,
        0.0 AS total_returns
    FROM catalog_sales cs
    JOIN call_center cc_sales
        ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN item i_sales
        ON cs.cs_item_sk = i_sales.i_item_sk
    JOIN promotion p_sales
        ON cs.cs_promo_sk = p_sales.p_promo_sk
    JOIN promotion p_sales_extra
        ON p_sales.p_item_sk = i_sales.i_item_sk
    JOIN item i_sales_extra
        ON p_sales_extra.p_item_sk = i_sales_extra.i_item_sk
    GROUP BY cc_sales.cc_name, i_sales.i_category
),
returns_agg AS (
    SELECT
        cc_ret.cc_name AS call_center_name,
        i_ret.i_category AS item_category,
        0.0 AS total_sales,
        SUM(r.total_return_amount) AS total_returns
    FROM returns_raw r
    JOIN call_center cc_ret
        ON r.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN item i_ret
        ON r.cr_item_sk = i_ret.i_item_sk
    JOIN promotion p_ret
        ON p_ret.p_item_sk = i_ret.i_item_sk
    JOIN promotion p_ret_extra
        ON p_ret.p_item_sk = i_ret.i_item_sk
    GROUP BY cc_ret.cc_name, i_ret.i_category
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY total_sales DESC, total_returns DESC
LIMIT 100
