WITH store_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY p.p_promo_id, d.d_year, d.d_month_seq
),
inventory_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    COALESCE(ss.p_promo_id, ws.p_promo_id, cs.p_promo_id, sr.p_promo_id, wr.p_promo_id) AS promo_id,
    COALESCE(ss.d_year, ws.d_year, cs.d_year, sr.d_year, wr.d_year) AS year,
    COALESCE(ss.d_month_seq, ws.d_month_seq, cs.d_month_seq, sr.d_month_seq, wr.d_month_seq) AS month_seq,
    COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) AS total_net_profit,
    COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
    COALESCE(ss.store_customer_cnt, 0) + COALESCE(ws.web_customer_cnt, 0) + COALESCE(cs.catalog_customer_cnt, 0) AS total_customers,
    COALESCE(sr.store_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0) AS total_returns,
    i.total_inventory
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.p_promo_id = ws.p_promo_id
   AND ss.d_year = ws.d_year
   AND ss.d_month_seq = ws.d_month_seq
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.p_promo_id, ws.p_promo_id) = cs.p_promo_id
   AND COALESCE(ss.d_year, ws.d_year) = cs.d_year
   AND COALESCE(ss.d_month_seq, ws.d_month_seq) = cs.d_month_seq
FULL OUTER JOIN store_returns_agg sr
    ON COALESCE(ss.p_promo_id, ws.p_promo_id, cs.p_promo_id) = sr.p_promo_id
   AND COALESCE(ss.d_year, ws.d_year, cs.d_year) = sr.d_year
   AND COALESCE(ss.d_month_seq, ws.d_month_seq, cs.d_month_seq) = sr.d_month_seq
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(ss.p_promo_id, ws.p_promo_id, cs.p_promo_id, sr.p_promo_id) = wr.p_promo_id
   AND COALESCE(ss.d_year, ws.d_year, cs.d_year, sr.d_year) = wr.d_year
   AND COALESCE(ss.d_month_seq, ws.d_month_seq, cs.d_month_seq, sr.d_month_seq) = wr.d_month_seq
FULL OUTER JOIN inventory_agg i
    ON COALESCE(ss.d_year, ws.d_year, cs.d_year, sr.d_year, wr.d_year) = i.d_year
   AND COALESCE(ss.d_month_seq, ws.d_month_seq, cs.d_month_seq, sr.d_month_seq, wr.d_month_seq) = i.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
