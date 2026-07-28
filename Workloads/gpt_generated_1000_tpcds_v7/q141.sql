WITH base AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_color,
        p.p_promo_id,
        p.p_discount_active,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_return_amount,
        r.r_reason_desc,
        cc.cc_name,
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender
    FROM item i
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
),
sales_agg AS (
    SELECT
        i_item_id,
        i_color,
        p_promo_id,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(ss_net_paid) AS sum_ss_net_paid,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(cr_return_amount) AS sum_return_amount,
        COUNT(*) AS txn_count,
        -- preserve columns needed for windowing / further calculations
        MAX(p_discount_active) AS p_discount_active,
        MAX(cs_sold_date_sk) AS cs_sold_date_sk
    FROM base
    WHERE i_color = 'turquoise'
      AND p_discount_active = 'Y'
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450400
    GROUP BY i_item_id, i_color, p_promo_id
)
SELECT
    i_item_id,
    i_color,
    p_promo_id,
    sum_cs_net_paid,
    sum_ss_net_paid,
    sum_ws_net_paid,
    sum_return_amount,
    txn_count,
    (sum_cs_net_paid + sum_ss_net_paid + sum_ws_net_paid - sum_return_amount) AS net_total,
    ROW_NUMBER() OVER (PARTITION BY i_color ORDER BY (sum_cs_net_paid + sum_ss_net_paid + sum_ws_net_paid - sum_return_amount) DESC) AS rn
FROM sales_agg
ORDER BY net_total DESC
LIMIT 100
