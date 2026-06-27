WITH catalog AS (
    SELECT 
        p.p_promo_sk,
        sum(cs.cs_ext_sales_price) AS catalog_sales,
        sum(cs.cs_net_profit) AS catalog_profit,
        sum(cr.cr_return_amount) AS catalog_returns
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    GROUP BY p.p_promo_sk
),
store AS (
    SELECT 
        p.p_promo_sk,
        sum(ss.ss_ext_sales_price) AS store_sales,
        sum(ss.ss_net_profit) AS store_profit,
        sum(sr.sr_return_amt) AS store_returns
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    GROUP BY p.p_promo_sk
),
web AS (
    SELECT 
        p.p_promo_sk,
        sum(ws.ws_ext_sales_price) AS web_sales,
        sum(ws.ws_net_profit) AS web_profit,
        sum(wr.wr_return_amt) AS web_returns
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY p.p_promo_sk
)
SELECT 
    p.p_promo_id,
    coalesce(c.catalog_sales, 0) AS catalog_sales,
    coalesce(s.store_sales, 0)   AS store_sales,
    coalesce(w.web_sales, 0)    AS web_sales,
    coalesce(c.catalog_returns, 0) AS catalog_returns,
    coalesce(s.store_returns, 0)   AS store_returns,
    coalesce(w.web_returns, 0)    AS web_returns,
    coalesce(c.catalog_profit, 0) AS catalog_profit,
    coalesce(s.store_profit, 0)   AS store_profit,
    coalesce(w.web_profit, 0)    AS web_profit,
    (coalesce(c.catalog_sales, 0) + coalesce(s.store_sales, 0) + coalesce(w.web_sales, 0)) AS total_sales,
    (coalesce(c.catalog_returns, 0) + coalesce(s.store_returns, 0) + coalesce(w.web_returns, 0)) AS total_returns,
    (coalesce(c.catalog_profit, 0) + coalesce(s.store_profit, 0) + coalesce(w.web_profit, 0)) AS total_profit
FROM promotion p
LEFT JOIN catalog c
    ON p.p_promo_sk = c.p_promo_sk
LEFT JOIN store s
    ON p.p_promo_sk = s.p_promo_sk
LEFT JOIN web w
    ON p.p_promo_sk = w.p_promo_sk
ORDER BY total_sales DESC
LIMIT 10
