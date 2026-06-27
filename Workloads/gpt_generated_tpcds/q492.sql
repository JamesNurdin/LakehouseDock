WITH sales_union AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        ss.ss_net_profit AS net_amount,
        ss.ss_quantity AS qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    UNION ALL
    SELECT
        cs.cs_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        cs.cs_net_profit AS net_amount,
        cs.cs_quantity AS qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    UNION ALL
    SELECT
        ws.ws_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        ws.ws_net_profit AS net_amount,
        ws.ws_quantity AS qty
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
),
returns_union AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        -sr.sr_net_loss AS net_amount,
        -sr.sr_return_quantity AS qty
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    UNION ALL
    SELECT
        p.p_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        -cr.cr_net_loss AS net_amount,
        -cr.cr_return_quantity AS qty
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    UNION ALL
    SELECT
        p.p_promo_sk AS promo_sk,
        date_trunc('month', d.d_date) AS month,
        -wr.wr_net_loss AS net_amount,
        -wr.wr_return_quantity AS qty
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
),
combined AS (
    SELECT promo_sk, month, net_amount, qty FROM sales_union
    UNION ALL
    SELECT promo_sk, month, net_amount, qty FROM returns_union
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    c.month,
    SUM(c.net_amount) AS net_profit,
    SUM(c.qty) AS net_quantity
FROM combined c
JOIN promotion p ON c.promo_sk = p.p_promo_sk
GROUP BY p.p_promo_id, p.p_promo_name, c.month
ORDER BY net_profit DESC
LIMIT 10
