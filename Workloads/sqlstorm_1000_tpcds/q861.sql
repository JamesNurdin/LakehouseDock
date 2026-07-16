WITH sales AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        'catalog' AS channel,
        cs.cs_order_number AS order_id,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS net_profit,
        cd.cd_credit_rating AS credit_rating,
        COALESCE(cr.cr_net_loss, 0) AS return_loss,
        CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promotion_flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN promotion p ON p.p_item_sk = cs.cs_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND p.p_discount_active = 'Y'
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        'store' AS channel,
        ss.ss_ticket_number AS order_id,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_net_profit AS net_profit,
        cd.cd_credit_rating AS credit_rating,
        COALESCE(sr.sr_net_loss, 0) AS return_loss,
        CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promotion_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN promotion p ON p.p_item_sk = ss.ss_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND p.p_discount_active = 'Y'
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        'web' AS channel,
        ws.ws_order_number AS order_id,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit AS net_profit,
        cd.cd_credit_rating AS credit_rating,
        COALESCE(wr.wr_net_loss, 0) AS return_loss,
        CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promotion_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN promotion p ON p.p_item_sk = ws.ws_item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND p.p_discount_active = 'Y'
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    year,
    month,
    category,
    SUM(net_profit) - SUM(return_loss) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    AVG(discount_amt) AS avg_discount_amount,
    SUM(promotion_flag) AS promo_sales_count,
    SUM(promotion_flag) * 1.0 / COUNT(*) AS promo_sales_ratio,
    RANK() OVER (PARTITION BY year, month ORDER BY SUM(net_profit) - SUM(return_loss) DESC) AS profit_rank
FROM sales
WHERE credit_rating = 'Excellent'
GROUP BY year, month, category
HAVING SUM(net_profit) - SUM(return_loss) > 0
ORDER BY year, month, profit_rank
LIMIT 100
