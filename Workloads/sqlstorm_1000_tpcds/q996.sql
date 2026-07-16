WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        'web'
    FROM web_sales ws
),
returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS loss,
        'catalog' AS channel
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS loss,
        'store' AS channel
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS loss,
        'web' AS channel
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    s.channel,
    SUM(s.profit) AS total_profit,
    SUM(s.discount) AS total_discount,
    COALESCE(SUM(r.loss), 0) AS total_return_loss,
    SUM(s.profit) - COALESCE(SUM(r.loss), 0) AS net_profit_adj,
    COUNT(DISTINCT s.item_sk) AS unique_items_sold,
    AVG(p.p_cost) AS avg_promo_cost
FROM sales s
LEFT JOIN returns r
    ON s.date_sk = r.date_sk
    AND s.item_sk = r.item_sk
    AND s.channel = r.channel
JOIN date_dim d
    ON s.date_sk = d.d_date_sk
JOIN item i
    ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON s.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category, i.i_brand, s.channel
HAVING SUM(s.profit) > 0
ORDER BY d.d_year, i.i_category, i.i_brand, s.channel
