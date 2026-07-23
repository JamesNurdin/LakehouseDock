WITH sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_brand,
        i.i_product_name,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        regexp_extract(i.i_product_name, '\\d+', 0) AS product_code
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_item_sk, i.i_brand, i.i_product_name, regexp_extract(i.i_product_name, '\\d+', 0)
),
returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_email,
        p.p_item_sk AS item_sk
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '^Promo.*[0-9]{2}$')
      AND p.p_channel_email = 'Y'
)
SELECT DISTINCT
    s.i_brand,
    s.i_product_name,
    substring(s.i_product_name, 1, 10) AS short_name,
    concat(s.i_brand, '-', s.product_code) AS brand_product_code,
    s.product_code,
    s.total_quantity,
    s.total_net_paid,
    s.total_net_profit,
    r.return_count,
    r.total_return_qty,
    r.total_return_amt,
    r.total_net_loss,
    p.p_promo_name,
    p.p_channel_email
FROM sales_agg s
JOIN returns_agg r ON s.item_sk = r.item_sk
JOIN promo_filtered p ON s.item_sk = p.item_sk
WHERE s.i_product_name LIKE '%-A%'
  AND substring(p.p_promo_name, 1, 5) = 'Promo'
ORDER BY s.total_net_profit DESC
LIMIT 100
