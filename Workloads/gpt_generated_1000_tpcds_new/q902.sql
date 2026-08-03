WITH
    -- Aggregate store_sales (pre‑aggregation)
    ss_agg AS (
        SELECT
            ss_customer_sk AS customer_sk,
            ss_cdemo_sk   AS cdemo_sk,
            ss_promo_sk   AS promo_sk,
            SUM(ss_ext_sales_price) AS total_ss_sales,
            COUNT(*)                AS cnt_ss,
            AVG(ss_sales_price)     AS avg_ss_price
        FROM store_sales
        WHERE ss_quantity >= 1
          AND ss_net_paid_inc_tax > 500
          AND ss_ext_discount_amt < 200
          AND ss_ext_sales_price > 0
        GROUP BY ss_customer_sk, ss_cdemo_sk, ss_promo_sk
    ),
    -- Aggregate catalog_sales (pre‑aggregation)
    cs_agg AS (
        SELECT
            cs_bill_customer_sk AS customer_sk,
            cs_bill_cdemo_sk    AS cdemo_sk,
            cs_promo_sk         AS promo_sk,
            SUM(cs_ext_sales_price) AS total_cs_sales,
            COUNT(*)                AS cnt_cs,
            AVG(cs_sales_price)     AS avg_cs_price
        FROM catalog_sales
        WHERE cs_quantity > 1
          AND cs_wholesale_cost > 10
          AND cs_ext_discount_amt < 100
          AND cs_ext_sales_price > 0
        GROUP BY cs_bill_customer_sk, cs_bill_cdemo_sk, cs_promo_sk
    ),
    -- UNION of promotion keys (distinct)
    promo_union AS (
        SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y'
        UNION
        SELECT p_promo_sk FROM promotion WHERE p_channel_email = 'Y'
    ),
    -- INTERSECT of promotion keys
    promo_intersect AS (
        SELECT p_promo_sk FROM promotion WHERE p_channel_tv = 'Y'
        INTERSECT
        SELECT p_promo_sk FROM promotion WHERE p_channel_radio = 'Y'
    ),
    -- EXCEPT of demographic keys
    demo_except AS (
        SELECT cd_demo_sk FROM customer_demographics WHERE cd_credit_rating = 'A'
        EXCEPT
        SELECT cd_demo_sk FROM customer_demographics WHERE cd_dep_count = 0
    )
SELECT
    u.customer_sk,
    u.promo_sk,
    u.p_promo_name,
    u.cd_gender,
    u.cd_marital_status,
    u.cd_credit_rating,
    u.total_sales,
    u.txn_cnt,
    u.avg_price,
    ROW_NUMBER() OVER (PARTITION BY u.cd_gender ORDER BY u.total_sales DESC) AS gender_rank,
    (SELECT SUM(cs_ext_sales_price)
       FROM catalog_sales cs
       WHERE cs.cs_bill_customer_sk = u.customer_sk) AS corr_total_catalog_sales
FROM (
    -- Store‑sales side (uses FULL OUTER JOIN to keep unmatched rows)
    SELECT
        ss.customer_sk,
        ss.promo_sk,
        ss.cdemo_sk,
        ss.total_ss_sales      AS total_sales,
        ss.cnt_ss              AS txn_cnt,
        ss.avg_ss_price        AS avg_price,
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        cd.cd_demo_sk
    FROM ss_agg ss
    FULL OUTER JOIN customer_demographics cd
        ON ss.cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.promo_sk = p.p_promo_sk

    UNION

    -- Catalog‑sales side
    SELECT
        cs.customer_sk,
        cs.promo_sk,
        cs.cdemo_sk,
        cs.total_cs_sales      AS total_sales,
        cs.cnt_cs              AS txn_cnt,
        cs.avg_cs_price        AS avg_price,
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        cd.cd_demo_sk
    FROM cs_agg cs
    JOIN promotion p
        ON cs.promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON cs.cdemo_sk = cd.cd_demo_sk
) u
WHERE
    u.p_promo_name IS NOT NULL
    AND u.cd_gender = 'M'
    AND u.cd_marital_status = 'M'
    AND u.cd_credit_rating = 'A'
    AND u.cd_dep_count BETWEEN 2 AND 5
    AND EXISTS (SELECT 1 FROM promo_union pu   WHERE pu.p_promo_sk = u.promo_sk)
    AND EXISTS (SELECT 1 FROM promo_intersect pi WHERE pi.p_promo_sk = u.promo_sk)
    AND u.cd_demo_sk IN (SELECT cd_demo_sk FROM demo_except)
ORDER BY u.total_sales DESC
LIMIT 100
