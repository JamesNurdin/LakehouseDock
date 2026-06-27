/* Net profit per promotion per month for the year 2000 */
WITH store_sales_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS web_net_paid
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(s.promo_id, c.promo_id, cr.promo_id, w.promo_id, wr.promo_id) AS promo_id,
    COALESCE(s.d_year, c.d_year, cr.d_year, w.d_year, wr.d_year) AS year,
    COALESCE(s.d_month_seq, c.d_month_seq, cr.d_month_seq, w.d_month_seq, wr.d_month_seq) AS month_seq,
    COALESCE(s.store_net_paid, 0) AS store_sales_net_paid,
    COALESCE(c.catalog_net_paid, 0) AS catalog_sales_net_paid,
    COALESCE(w.web_net_paid, 0) AS web_sales_net_paid,
    COALESCE(cr.catalog_net_loss, 0) AS catalog_returns_net_loss,
    COALESCE(wr.web_net_loss, 0) AS web_returns_net_loss,
    (COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0)
     - COALESCE(cr.catalog_net_loss, 0) - COALESCE(wr.web_net_loss, 0)) AS net_profit
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c
    ON s.promo_id = c.promo_id
   AND s.d_year = c.d_year
   AND s.d_month_seq = c.d_month_seq
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(s.promo_id, c.promo_id) = cr.promo_id
   AND COALESCE(s.d_year, c.d_year) = cr.d_year
   AND COALESCE(s.d_month_seq, c.d_month_seq) = cr.d_month_seq
FULL OUTER JOIN web_sales_agg w
    ON COALESCE(s.promo_id, c.promo_id, cr.promo_id) = w.promo_id
   AND COALESCE(s.d_year, c.d_year, cr.d_year) = w.d_year
   AND COALESCE(s.d_month_seq, c.d_month_seq, cr.d_month_seq) = w.d_month_seq
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(s.promo_id, c.promo_id, cr.promo_id, w.promo_id) = wr.promo_id
   AND COALESCE(s.d_year, c.d_year, cr.d_year, w.d_year) = wr.d_year
   AND COALESCE(s.d_month_seq, c.d_month_seq, cr.d_month_seq, w.d_month_seq) = wr.d_month_seq
ORDER BY net_profit DESC
LIMIT 20
